pipeline {
    agent any

    stages {
        stage('Test Library Availability') {
            steps {
                script {
                    echo "Checking system registry for your library..."
                    try {
                        // 1. Force a dynamic pull of your library name and target branch
                        // Replace 'your-library-name' with the exact string in Manage Jenkins
                        library 'xmos_jenkins_shared_library@v0.43.3' 
                        
                        echo "SUCCESS: Jenkins found and successfully checked out the library!"
                        
                        // 2. Check which exact version/commit hash Jenkins fetched
                        echo "Loaded version tag: ${env.'library.your-library-name.version'}"
                        
                    } catch (Exception e) {
                        echo "FAILURE: The library could not be reached or resolved."
                        echo "Error Details: ${e.getMessage()}"
                    }
                }
            }
        }
    }
}

