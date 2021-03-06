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

def test(arg){
  
  println("Running test"+arg)
  def s=3*arg
  sh "sleep ${s}"
  def response = httpRequest 'http://staging.laur.work'
  println("Status: "+response.status)

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
                  def image = "${image_name}:${env.CHANGE_ID}"
                  docker("build -t ${image} .")
                  docker("push ${image} && docker rmi ${image}")
                }
              }
            }
            stage('deploy to staging'){
              steps{
                dir("chart/app"){
                  script {
                    helm("upgrade staging --install --namespace staging --set image.tag=${env.CHANGE_ID} --set fullnameOverride=app-staging --wait --timeout 600 .")
                  }
                }
              }
            }
            stage('integration tests'){
              parallel {
                stage('test-1') {
                    steps {
                        script {
                            test(1)
                        }
                    }
                }
                stage('test-2') {
                    steps {
                        script {
                            test(2)
                        }
                    }
                }
                stage('test-3') {
                    steps {
                        script {
                            test(3)
                        }
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
            stage('deploy to prod'){
              steps{
                dir("chart/app"){
                  script {
                    def commitText = sh(returnStdout: true, script: 'git show -s --format=format:"%s" HEAD | sed "s/#/number/"').trim()
                    def release = commitText.split("number")[1].split(" ")[0]
                    helm("upgrade prod --install --namespace staging --set image.tag=${release} --set fullnameOverride=app-prod --wait --timeout 600 .")
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