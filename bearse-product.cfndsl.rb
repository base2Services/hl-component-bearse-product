CloudFormation do

  provisioning_artifact_parameters = versions.map do |ver|
    puts ver
    {
      Description: ver['desc'],
      Info: {
        LoadTemplateFromURL: FnJoin('', ['https://', FnImportValue(FnSub("${EnvironmentName}-bearse-service-catalog-bucket-domain-name")), "/#{name}/#{ver['name']}/template.yaml" ])
      },
      Name: ver['name']
    }
  end

  ServiceCatalog_CloudFormationProduct(:Product) {
    AcceptLanguage 'en'
    Description description
    Distributor 'base2services'
    Name name
    ProvisioningArtifactParameters provisioning_artifact_parameters
    SupportDescription 'base2services help desk support'
    SupportEmail 'helpdesk@base2services.com.au'
    SupportUrl "https://bearse.ci.base2.services/feature/#{name}"
    Tags([
      { Key: 'bearse:environment', Value: Ref('EnvironmentName') },
      { Key: 'bearse:feature:name', Value: name },
    ])
  }
  
  ServiceCatalog_PortfolioProductAssociation(:Association) {
    AcceptLanguage 'en'
    PortfolioId FnImportValue(FnSub("${EnvironmentName}-bearse-service-catalog-portfolio-id"))
    ProductId Ref(:Product)
  }
  
  ServiceCatalog_LaunchNotificationConstraint(:LaunchNotificationConstraint) {
    NotificationArns FnImportValue(FnSub("${EnvironmentName}-bearse-service-catalog-sns-topic"))
    PortfolioId FnImportValue(FnSub("${EnvironmentName}-bearse-service-catalog-portfolio-id"))
    ProductId Ref(:Product)
  }
  
  policies = []
  
  actions = %w(
    cloudformation:CreateStack
    cloudformation:DeleteStack
    cloudformation:DescribeStackEvents
    cloudformation:DescribeStacks
    cloudformation:SetStackPolicy
    cloudformation:ValidateTemplate
    cloudformation:UpdateStack
  )
  resources = %w(
    arn:aws:cloudformation:*:*:stack/SC-*
    arn:aws:cloudformation:*:*:changeSet/SC-*
  )
  policies << iam_policy_allow('CloudformationManagement',actions,resources)
  policies << iam_policy_allow('AllowSnsNotifications','sns:Publish',FnImportValue(FnSub("${EnvironmentName}-bearse-service-catalog-sns-topic")))
  policies << iam_policy_allow('AllowProductLaunch',['cloudformation:GetTemplateSummary', 's3:GetObject'],'*')
  
  iam_policies.each do |name,policy|
    policies << iam_policy_allow(name,policy['action'],policy['resource'] || '*')
  end if defined? iam_policies
  
  IAM_Role(:LaunchRole) {
    AssumeRolePolicyDocument service_role_assume_policy('servicecatalog.amazonaws.com')
    Path '/'
    Policies(policies)
  }
  
  ServiceCatalog_LaunchRoleConstraint(:LaunchRoleConstraint) {
    DependsOn 'Association'
    PortfolioId FnImportValue(FnSub("${EnvironmentName}-bearse-service-catalog-portfolio-id"))
    ProductId Ref(:Product)
    RoleArn FnGetAtt(:LaunchRole, :Arn)
  }
  
end
