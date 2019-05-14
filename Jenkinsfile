pipeline {
    agent any

    environment {
        SHORT_SHA = env.GIT_COMMIT.substring(0,6)
    }

    stages {

        stage('check tools') {
            steps {
                script {
                    sh "env"
                }
            }
        }
    }
}