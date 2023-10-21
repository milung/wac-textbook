function run {
    if (Test-Path -Path "${PWD}/scripts/run.ps1") {
        invoke-expression "${PWD}/scripts/run.ps1 $args"
    }
    else {
        if(Test-Path -Path "${PWD}/package.json") {
        npm run $args
        }
        else {
            echo "No run.ps1 or package.json found in the current folder"
        } 
    }
}