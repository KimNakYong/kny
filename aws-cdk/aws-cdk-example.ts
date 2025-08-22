import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as ecr from 'aws-cdk-lib/aws-ecr';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as logs from 'aws-cdk-lib/aws-logs';
import { Construct } from 'constructs';

export class TFMicroservicesStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // VPC 생성
    const vpc = new ec2.Vpc(this, 'TFVPC', {
      maxAzs: 2,
      natGateways: 1,
    });

    // ECS Cluster 생성
    const cluster = new ecs.Cluster(this, 'TFCluster', {
      vpc,
      clusterName: 'tf-microservices-cluster',
    });

    // Application Load Balancer 생성
    const alb = new elbv2.ApplicationLoadBalancer(this, 'TFALB', {
      vpc,
      internetFacing: true,
      loadBalancerName: 'tf-microservices-alb',
    });

    // User Service
    this.createService('user-service', 8085, cluster, alb, vpc);
    
    // Store Service  
    this.createService('store-service', 8081, cluster, alb, vpc);
    
    // Booking Service
    this.createService('booking-service', 8080, cluster, alb, vpc);
  }

  private createService(
    serviceName: string, 
    port: number, 
    cluster: ecs.Cluster, 
    alb: elbv2.ApplicationLoadBalancer,
    vpc: ec2.Vpc
  ) {
    // ECR Repository 생성
    const repository = new ecr.Repository(this, `${serviceName}-repo`, {
      repositoryName: `tf-${serviceName}`,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    // Task Definition 생성
    const taskDefinition = new ecs.FargateTaskDefinition(this, `${serviceName}-task`, {
      memoryLimitMiB: 512,
      cpu: 256,
    });

    // Container 정의
    const container = taskDefinition.addContainer(`${serviceName}-container`, {
      image: ecs.ContainerImage.fromEcrRepository(repository),
      logging: ecs.LogDrivers.awsLogs({
        streamPrefix: serviceName,
        logRetention: logs.RetentionDays.ONE_WEEK,
      }),
      environment: {
        'SPRING_PROFILES_ACTIVE': 'prod',
      },
    });

    container.addPortMappings({
      containerPort: port,
      protocol: ecs.Protocol.TCP,
    });

    // Security Group 생성
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

    // ECS Service 생성
    const service = new ecs.FargateService(this, `${serviceName}-service`, {
      cluster,
      taskDefinition,
      serviceName: `tf-${serviceName}`,
      desiredCount: 2,
      securityGroups: [securityGroup],
      assignPublicIp: true,
    });

    // ALB Target Group 생성
    const targetGroup = new elbv2.ApplicationTargetGroup(this, `${serviceName}-tg`, {
      vpc,
      port: port,
      protocol: elbv2.ApplicationProtocol.HTTP,
      targetType: elbv2.TargetType.IP,
      healthCheck: {
        path: '/actuator/health',
        healthyHttpCodes: '200',
      },
    });

    // ALB Listener Rule 생성
    alb.addListener(`${serviceName}-listener`, {
      port: 80,
      defaultTargetGroups: [targetGroup],
    });

    // Auto Scaling 설정
    const scaling = service.autoScaleTaskCount({
      maxCapacity: 5,
      minCapacity: 1,
    });

    scaling.scaleOnCpuUtilization(`${serviceName}-cpu-scaling`, {
      targetUtilizationPercent: 70,
      scaleInCooldown: cdk.Duration.seconds(60),
      scaleOutCooldown: cdk.Duration.seconds(60),
    });

    // CloudWatch Dashboard 생성
    new cdk.CfnOutput(this, `${serviceName}-url`, {
      value: `http://${alb.loadBalancerDnsName}`,
      description: `${serviceName} Load Balancer URL`,
    });
  }
}
