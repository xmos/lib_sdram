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
        stage('checkout and build') {
            agent {
                // label 'x86_64 && linux && documentation'
                label 'built-in'
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
                            sh 'pwd'
                            sh 'ls -la'
                        }
                        echo 'checkout done'
                    }
                }
                stage('examples build') {         
                    steps {
                        echo 'example build'
                        checkout scm
                        dir("${REPO_NAME}/examples/app_sdram_demo") {
                            // xcoreBuild()
                            // sh 'which cmake'
                            // sh 'pwd'
                            // sh 'ls -la'
                            // sh 'cmake -B build'
                            // sh 'xmake -C build -j'
                            sh '''
                                source /home/alexyiu/xmos/tools/XMOS/xTIMEcomposer/Community_14.4.1/SetEnv
                                which cmake
                                pwd
                                ls -la
                                cmake -B build
                                xmake -C build -j
                            '''
                        }
                        echo 'build success'
                    }
                }
            }

        }
    }
}
