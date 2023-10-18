param (
    $command 
)

if ( -not $command ) {
    $command = "start"
}

$ProjectRoot = "${PSScriptRoot}/.."


switch ($command) {

    "start" {
        docker run -it --rm -v ${ProjectRoot}/book-src/:/usr/src/app/book-src/ -p 3380:3380 milung/book-builder:latest
    }

    "devc-start" {
        $location = Get-Location
        try {
            cd /usr/src/app
            npm run serve-spa
        } finally {
            Set-Location $location
        }
    }

    "build" {
        docker build -f ${ProjectRoot}/build/docker/Dockerfile -t milung/book-builder:local ${ProjectRoot} 
    }

    default {
        Write-Output "Unknown command: $command"
        throw "Unknown command: $command"
    }
}

Write-Output "Done"