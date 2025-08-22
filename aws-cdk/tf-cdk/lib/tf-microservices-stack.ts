import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as ecr from 'aws-cdk-lib/aws-ecr';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import * as logs from 'aws-cdk-lib/aws-logs';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';

export class TFMicroservicesStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // 1. 기존 VPC 참조 (기본 VPC 사용)
    const vpc = ec2.Vpc.fromLookup(this, 'ExistingVPC', {
      isDefault: true,
    });

    // 2. 기존 ECS Cluster 참조
    const cluster = ecs.Cluster.fromClusterAttributes(this, 'ExistingCluster', {
      clusterName: 'tf-microservices-cluster',
      vpc: vpc,
    });

    // 3. 기존 ALB 참조 (실제 ARN으로 교체 필요)
    const alb = elbv2.ApplicationLoadBalancer.fromApplicationLoadBalancerAttributes(
      this, 'ExistingALB', {
        loadBalancerArn: 'arn:aws:elasticloadbalancing:ap-northeast-2:123456789012:loadbalancer/app/tf-alb/xxxxxxxxx', // 실제 ARN으로 교체
        loadBalancerDnsName: 'tf-alb-xxxxxxxxx.ap-northeast-2.elb.amazonaws.com', // 실제 DNS로 교체
        securityGroupId: 'sg-xxxxxxxxx', // 실제 Security Group ID로 교체
      }
    );

    // 4. 기존 ECR Repositories 참조
    const userRepo = ecr.Repository.fromRepositoryName(
      this, 'UserRepo', 'tf-user-service'
    );
    const storeRepo = ecr.Repository.fromRepositoryName(
      this, 'StoreRepo', 'tf-store-service'
    );
    const bookingRepo = ecr.Repository.fromRepositoryName(
      this, 'BookingRepo', 'tf-booking-service'
    );

    // 5. ECS Task Execution Role 생성
    const taskExecutionRole = new iam.Role(this, 'TaskExecutionRole', {
      assumedBy: new iam.ServicePrincipal('ecs-tasks.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AmazonECSTaskExecutionRolePolicy'),
      ],
    });

    // 6. 서비스별 리소스 생성
    this.createService('user-service', 8085, cluster, alb, vpc, userRepo, taskExecutionRole);
    this.createService('store-service', 8081, cluster, alb, vpc, storeRepo, taskExecutionRole);
    this.createService('booking-service', 8080, cluster, alb, vpc, bookingRepo, taskExecutionRole);

    // 7. CloudWatch Dashboard 생성
    this.createDashboard(cluster, alb);
  }

  private createService(
    serviceName: string,
    port: number,
    cluster: ecs.ICluster,
    alb: elbv2.IApplicationLoadBalancer,
    vpc: ec2.IVpc,
    repository: ecr.IRepository,
    taskExecutionRole: iam.Role
  ) {
    // Task Definition
    const taskDefinition = new ecs.FargateTaskDefinition(this, `${serviceName}-task`, {
      memoryLimitMiB: 512,
      cpu: 256,
      executionRole: taskExecutionRole,
    });

    const container = taskDefinition.addContainer(`${serviceName}-container`, {
      image: ecs.ContainerImage.fromEcrRepository(repository, 'latest'),
      logging: ecs.LogDrivers.awsLogs({
        streamPrefix: serviceName,
        logRetention: logs.RetentionDays.ONE_WEEK,
      }),
      environment: {
        'SPRING_PROFILES_ACTIVE': 'prod',
        'SERVER_PORT': port.toString(),
      },
    });

    container.addPortMappings({
      containerPort: port,
      protocol: ecs.Protocol.TCP,
    });

    // Security Group
    const securityGroup = new ec2.SecurityGroup(this, `${serviceName}-sg`, {
      vpc,
      description: `Security group for ${serviceName}`,
      allowAllOutbound: true,
    });

    securityGroup.addIngressRule(
      ec2.Peer.anyIpv4(),
      ec2.Port.tcp(port),
      `Allow ${serviceName} traffic`
    );

    // ECS Service
    const service = new ecs.FargateService(this, `${serviceName}-service`, {
      cluster,
      taskDefinition,
      serviceName: `tf-${serviceName}`,
      desiredCount: 2,
      securityGroups: [securityGroup],
      assignPublicIp: true,
    });

    // Target Group
    const targetGroup = new elbv2.ApplicationTargetGroup(this, `${serviceName}-tg`, {
      vpc,
      port: port,
      protocol: elbv2.ApplicationProtocol.HTTP,
      targetType: elbv2.TargetType.IP,
      healthCheck: {
        path: '/actuator/health',
        healthyHttpCodes: '200',
        interval: cdk.Duration.seconds(30),
        timeout: cdk.Duration.seconds(5),
        healthyThresholdCount: 2,
        unhealthyThresholdCount: 3,
      },
    });

    // Listener Rule (Path-based routing)
    alb.addListener(`${serviceName}-listener`, {
      port: 80,
      defaultTargetGroups: [targetGroup],
      conditions: [
        elbv2.ListenerCondition.pathPatterns([`/api/${serviceName.split('-')[0]}*`]),
      ],
    });

    // Auto Scaling
    const scaling = service.autoScaleTaskCount({
      maxCapacity: 5,
      minCapacity: 1,
    });

    scaling.scaleOnCpuUtilization(`${serviceName}-cpu-scaling`, {
      targetUtilizationPercent: 70,
      scaleInCooldown: cdk.Duration.seconds(60),
      scaleOutCooldown: cdk.Duration.seconds(60),
    });

    scaling.scaleOnMemoryUtilization(`${serviceName}-memory-scaling`, {
      targetUtilizationPercent: 80,
      scaleInCooldown: cdk.Duration.seconds(60),
      scaleOutCooldown: cdk.Duration.seconds(60),
    });

    // Outputs
    new cdk.CfnOutput(this, `${serviceName}-service-url`, {
      value: `http://${alb.loadBalancerDnsName}/api/${serviceName.split('-')[0]}`,
      description: `${serviceName} Service URL`,
    });
  }

  private createDashboard(cluster: ecs.ICluster, alb: elbv2.IApplicationLoadBalancer) {
    // CloudWatch Dashboard 생성
    new cdk.CfnOutput(this, 'dashboard-url', {
      value: `https://${this.region}.console.aws.amazon.com/cloudwatch/home?region=${this.region}#dashboards:name=TFMicroservices`,
      description: 'CloudWatch Dashboard URL',
    });

    new cdk.CfnOutput(this, 'alb-dns', {
      value: alb.loadBalancerDnsName,
      description: 'Application Load Balancer DNS Name',
    });

    new cdk.CfnOutput(this, 'cluster-name', {
      value: cluster.clusterName,
      description: 'ECS Cluster Name',
    });
  }
}
