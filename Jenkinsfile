pipeline {
    agent any

    environment {
        tag = env.BUILD_NUMBER ?: "latest"
        dockerHubUser = ''
        containerName = "ercli-bankingapp_cep2"
        httpPort = "8989"
    }

    stages {
        stage('Prepare Environment') {
            steps {
                echo 'Initialize Environment'
                withCredentials([usernamePassword(credentialsId: 'ERCLI-DockerHub-Credentials', usernameVariable: 'dockerUser', passwordVariable: 'dockerPassword')]) {
                    script {
                        dockerHubUser = "${dockerUser}"
                    }
                }
            }
        }

        stage('Code Checkout') {
            steps {
                catchError {
                    echo 'Code Checkout'
                    checkout scm
                }
            }
        }

        stage('Maven Build') {
            steps {
                echo 'Maven Build'
                sh 'mvn clean package'
            }
        }

        stage('Docker Image Build') {
            steps {
                echo 'Creating Docker image'
                sh "docker build -t ${dockerHubUser}/${containerName}:${tag} --pull --no-cache ."
            }
        }

        stage('Docker Image Scan') {
            steps {
                echo 'Scanning Docker image for vulnerabilities'
                sh "trivy image --severity HIGH,CRITICAL ${dockerHubUser}/${containerName}:${tag}"
            }
        }

        stage('Check Docker Image in DockerHub') {
            steps {
                script {
                    def imageExists = sh(
                        script: "docker pull ${dockerHubUser}/${containerName}:${tag} > /dev/null && echo 'success' || echo 'failed'",
                        returnStdout: true
                    ).trim()
                    if (imageExists == 'success') {
                        error("Image ${dockerHubUser}/${containerName}:${tag} already exists in DockerHub. Process will not proceed.")
                    } else {
                        echo "Image ${dockerHubUser}/${containerName}:${tag} does not exist yet in DockerHub. Proceeding to the next stage."
                    }
                }
            }
        }

        stage('Publishing Image to DockerHub') {
            steps {
                echo 'Pushing the docker image to DockerHub'
                withCredentials([usernamePassword(credentialsId: 'ERCLI-DockerHub-Credentials', usernameVariable: 'dockerUser', passwordVariable: 'dockerPassword')]) {
                    sh "docker login -u ${dockerUser} -p ${dockerPassword}"
                    sh "docker push ${dockerUser}/${containerName}:${tag}"
                    echo "Image push complete"
                }
            }
        }

        stage('Deleting Local Docker Image') {
            steps {
                echo 'Deleting the docker image from the local machine'
                sh "docker rmi ${dockerHubUser}/${containerName}:${tag}"
                echo "Image deletion complete"
            }
        }
    }
}
