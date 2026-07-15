// This file relates to internal XMOS infrastructure and should be ignored by external users

@Library('xmos_jenkins_shared_library@v0.43.3') _

getApproval()
pipeline {

    agent none

    // parameters {
    //     string(
    //         name: 'TOOLS_VERSION',
    //         defaultValue: '15.3.1',
    //         description: 'XTC tools version'
    //     )
    //     string(
    //         name: 'XMOSDOC_VERSION',
    //         defaultValue: 'v8.0.0',
    //         description: 'xmosdoc version'
    //     )
    //     // string(
    //     //     name: 'INFR_APPS_VERSION',
    //     //     defaultValue: 'v3.1.1',
    //     //     description: 'The infr_apps version'
    //     // )
    //     // choice(
    //     //     name: 'TEST_LEVEL', choices: ['smoke', 'default', 'extended'],
    //     //     description: 'The level of test coverage to run'
    //     // )
    // }

    // options {
    //     skipDefaultCheckout()
    //     timestamps()
    //     buildDiscarder(xmosDiscardBuildSettings(onlyArtifacts = false))
    // }

    stages {
        stage('🏗️ Build and test') {
            // agent {
            //     label 'x86_64 && linux && documentation'
            // }
            agent none
            stages {
                stage('Checkout') {
                    steps {

                        // echo "Stage running on ${env.NODE_NAME}"
                        echo 'Read by Jenkins server?'

                        // script {
                        //     def (server, user, repo) = extractFromScmUrl()
                        //     env.REPO_NAME = repo
                        // }

                        // dir(REPO_NAME){
                        //     checkoutScmShallow()
                        // }
                    }
                }

        //         stage('Examples build') {
        //             steps {
        //                 dir("${REPO_NAME}/examples") {
        //                     xcoreBuild()
        //                 }
        //             }
        //         }

        //         stage('Repo checks') {
        //             steps {
        //                 warnError("Repo checks failed")
        //                 {
        //                     runRepoChecks("${WORKSPACE}/${REPO_NAME}")
        //                 }
        //             }
        //         }

        //         stage('Doc build') {
        //             steps {
        //                 dir(REPO_NAME) {
        //                     buildDocs()
        //                 }
        //             }
        //         }

        //         stage('Tests') {
        //             steps {
        //                 dir("${REPO_NAME}/tests") {
        //                     withTools(params.TOOLS_VERSION) {
        //                         createVenv(reqFile: "requirements.txt")
        //                         withVenv {
        //                             xcoreBuild(archiveBins: false)
        //                             // Use the TEST_LEVEL parameter to control the test coverage
        //                             runPytest("--level=${params.TEST_LEVEL}")
        //                         }
        //                     }
        //                 }
        //             }
        //         }

        //         stage("Archive sandbox") {
        //             steps {
        //                 archiveSandbox(REPO_NAME)
        //             }
        //         }
            } // stages
            // post {
            //     cleanup {
            //         xcoreCleanSandbox()
            //     }
            // }
        } // stage 'Build and test'

        // stage('🚀 Release') {
        //     when {
        //         expression { triggerRelease.isReleasable() }
        //     }
        //     steps {
        //         triggerRelease()
        //     }
        // }
    } // stages
} // pipeline
