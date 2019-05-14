def owner = "edbighead"
def app = "inther"
def image_name = owner+"/"+app

def docker(args){
  sh "docker ${args}"
}

def mvn(args){
  sh "mvn ${args}"
}

def helm(args){
  sh "helm ${args}"
}

pipeline {
    agent any

    environment {
        SHORT_SHA = env.GIT_COMMIT.substring(0,6)
    }

    stages {
        stage('cleanup') {
            steps {

              script {

                sh "env"
                deleteDir()

                def b = env.BRANCH_NAME
                if (env.CHANGE_BRANCH){
                  b=env.CHANGE_BRANCH
                }
                env.BRANCH_NAME=b
              }

              git (
                branch: env.BRANCH_NAME,
                credentialsId: '09142270-affe-4a3c-8889-c8c47315a5a5',
                url: env.GIT_URL
              )

            }
        }

        stage('development'){
          when {
            not { 
              environment name: 'GIT_BRANCH',
              value: 'master'
            }
          }
          stages{
            stage('run unit tests'){
              steps{
                withMaven( maven: 'mvn-3.5.4') {
                  mvn("test")
                }
                
              }
            }
          }
        }

        stage('staging'){
          when {
              expression { env.GIT_BRANCH =~ /PR\-\d+/ }
          }
          stages{
            stage('package'){
              steps{
                withMaven( maven: 'mvn-3.5.4') {
                  mvn("package -DskipTests")
                }
              }
            }
            stage('docker image'){
              steps{
                script {
                  def image = "${image_name}:${env.SHORT_SHA}"
                  docker("build -t ${image} .")
                  docker("push ${image} && docker rmi ${image}")
                }
              }
            }
            stage('deploy to staging'){
              steps{
                dir("chart/app"){
                  script {
                    helm("upgrade staging --install --namespace staging --set image.tag=${env.SHORT_SHA} --set fullnameOverride=app-staging --wait .")
                  }
                }
              }
            }
          }
        }

        stage('production'){
          when {
            environment name: 'GIT_BRANCH',
            value: 'master'
          }
          stages{
            stage('run unit tests'){
              steps{
                dir("chart/app"){
                  script {
                    helm("upgrade prod --install --namespace staging --set image.tag=${env.SHORT_SHA} --set fullnameOverride=app-prod --wait .")
                  }
                }
              }
            }
          }
        }
        
    }

  options {
    buildDiscarder(logRotator(numToKeepStr: '3'))
  }
}