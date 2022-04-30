$TSEnv = new-object -comobject Microsoft.SMS.TSEnvironment

if (-not (get-disk)){
    $TSEnv.Value("NoDiskDetected") = "true"
}