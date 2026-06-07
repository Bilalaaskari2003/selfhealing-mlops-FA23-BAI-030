pipeline {
    agent any

    environment {
        APP_CONTAINER  = "sentiment-app-test"
        DOCKER_NETWORK = "sentiment-net"
    }

    stages {

        stage('Fetch') {
            steps {
                checkout scm
            }
        }

        stage('Build and Run') {
            steps {
                sh """
                    docker build -t sentiment-api:unstable .
                    docker network create ${DOCKER_NETWORK} || true
                    docker run -d \
                        --name ${APP_CONTAINER} \
                        --network ${DOCKER_NETWORK} \
                        -p 5000:5000 \
                        sentiment-api:unstable
                    echo "Waiting for app to start..."
                    sleep 20
                """
            }
        }

        stage('Unit Test') {
            steps {
                sh """
                    docker run --rm \
                        --network ${DOCKER_NETWORK} \
                        -e BASE_URL=http://${APP_CONTAINER}:5000 \
                        sentiment-api:unstable \
                        pytest tests/test_api.py -v
                """
            }
        }

        stage('UI Test') {
            steps {
                sh """
                    docker run --rm \
                        --network ${DOCKER_NETWORK} \
                        -e BASE_URL=http://${APP_CONTAINER}:5000 \
                        sentiment-api:unstable \
                        pytest tests/test_ui.py -v
                """
            }
        }

        stage('Build and Push') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh """
                        echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin

                        # Build and push unstable image (main branch)
                        docker build -t \$DOCKER_USER/sentiment-api:unstable .
                        docker push \$DOCKER_USER/sentiment-api:unstable
                        
                        # Clone stable-fallback branch and build stable image
                        git clone --branch stable-fallback --depth 1 \$(git remote get-url origin) /tmp/stable-build
                        docker build -t \$DOCKER_USER/sentiment-api:stable /tmp/stable-build
                        docker push \$DOCKER_USER/sentiment-api:stable
                        rm -rf /tmp/stable-build
                    """
                }
            }
        }

        stage('Deploy to Minikube') {
            steps {
                sh """
                    kubectl apply -f k8s/pvc.yaml
                    kubectl apply -f k8s/blue-deployment.yaml
                    kubectl apply -f k8s/green-deployment.yaml
                    kubectl apply -f k8s/service.yaml
                """
            }
        }

    }

    post {
        always {
            sh """
                docker stop ${APP_CONTAINER}  || true
                docker rm   ${APP_CONTAINER}  || true
                docker network rm ${DOCKER_NETWORK} || true
            """
        }
    }
}
