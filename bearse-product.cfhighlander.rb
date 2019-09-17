CfhighlanderTemplate do
  Name 'bearse-product'
  Description "bearse-product - #{component_version}"

  Parameters do
    ComponentParam 'EnvironmentName', 'dev', isGlobal: true
    ComponentParam 'EnvironmentType', 'development', allowedValues: ['development','production'], isGlobal: true
  end


end
