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
                    docker rm -f ${APP_CONTAINER} || true
                    docker network rm ${DOCKER_NETWORK} || true
                    docker build -t sentiment-api:unstable .
                    docker network create ${DOCKER_NETWORK} || true
                    docker run -d \
                        --name ${APP_CONTAINER} \
                        --network ${DOCKER_NETWORK} \
                        -p 5000:5000 \
                        sentiment-api:unstable
                    sleep 10
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
                        docker build -t \$DOCKER_USER/sentiment-api:unstable .
                        docker push \$DOCKER_USER/sentiment-api:unstable
                        
                        rm -rf /tmp/stable-build
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
                    export KUBECONFIG=/var/lib/jenkins/.kube/config
                    kubectl apply -f k8s/pvc.yaml
                    kubectl apply -f k8s/blue-deployment.yaml
                    kubectl apply -f k8s/green-deployment.yaml
                    kubectl apply -f k8s/service.yaml
                    kubectl rollout status deployment/sentiment-blue-deployment --timeout=120s
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
