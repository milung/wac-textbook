param (
    $command 
)

if ( -not $command ) {
    $command = "start"
}

$ProjectRoot = "${PSScriptRoot}/.."


switch ($command) {

    "help": {
        Write-Output "Usage: run.ps1 <command>"
        Write-Output "Commands:"
        Write-Output "  start: start the book-builder container"
        Write-Output "  devc-start: start the server in dev container"
        Write-Output "  build: build the book-builder container"
        Write-Output "  makehtml: build the book"
        Write-Output "  help: show this help"
    }
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

    "makehtml" {
        $location = Get-Location
        try {
            cd /usr/src/app
            node ./build/makehtml/makehtml.mjs  --verbose --target ./www/book
        } finally {
            Set-Location $location
        } 
    }

    default {
        Write-Output "Unknown command: $command"
        throw "Unknown command: $command"
    }
}

Write-Output "Done"
