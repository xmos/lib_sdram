@Library('xmos_jenkins_shared_library@v0.43.3') _

// getApproval()

pipeline {
    agent any 
    
    options {
        skipDefaultCheckout()
        timestamps()
        buildDiscarder(xmosDiscardBuildSettings(onlyArtifacts=false))
    }
    
    parameters {
        string(
            name: 'TOOLS_VERSION',
            defaultValue: '15.3.1',
            description: 'XTC tools version'
        )
        string(
            name: 'XMOSDOC_VERSION',
            defaultValue: 'v8.0.0',
            description: 'xmosdoc version'
        )
        string(
            name: 'INFR_APPS_VERSION',
            defaultValue: 'v3.1.1',
            description: 'The infr_apps version'
        )
        choice(
            name: 'TEST_LEVEL', choices: ['smoke', 'default', 'extended'],
            description: 'The level of test coverage to run'
        )
    }

    stages {
        stage('checkout') {
            steps {
                echo 'checkout the repo'
                script {
                    def (server, user, repo) = extractFromScmUrl()
                    env.REPO_NAME = repo
                }
                dir(REPO_NAME){
                    checkoutScmShallow()
                }
                echo 'checkout done'
            }
        }
        stage('examples build') {
            steps {
                echo 'example build'
                dir("${REPO_NAME}/examples") {
                    xcoreBuild()
                }
                echo 'build success'
            }
        }
    }
}
