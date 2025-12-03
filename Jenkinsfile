pipeline {
    agent {
        label 'docker&&linux'
    }
    
    environment {
        ECR_URI = credentials('ecr-uri')
        AWS_ACCOUNT_ID = credentials('aws-account-id')
        AWS_REGION = 'us-east-1'
        ECR_REPOSITORY = 'python-ci-cd'
        IMAGE_TAG = "${env.BUILD_ID}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Setup Environment') {
            steps {
                script {
                    sh '''
                        echo "=== Verificando herramientas ==="
                        docker --version
                        aws --version
                        python3 --version
                        pip3 --version
                        trivy --version
                        echo "==============================="
                    '''
                }
            }
        }
        
        stage('Run Tests') {
            steps {
                sh '''
                    pip3 install -r requirements.txt
                    python3 -m pytest tests/ -v --cov=app --cov-report=xml
                '''
            }
            post {
                always {
                    junit '**/test-results/*.xml'
                    publishHTML(target: [
                        reportDir: 'htmlcov',
                        reportFiles: 'index.html',
                        reportName: 'Coverage Report'
                    ])
                }
            }
        }
        
        stage('Lint Code') {
            steps {
                sh '''
                    python3 -m py_compile app/*.py
                    echo "Linting básico completo"
                '''
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t ${ECR_REPOSITORY}:${IMAGE_TAG} ."
                    sh "docker tag ${ECR_REPOSITORY}:${IMAGE_TAG} ${ECR_REPOSITORY}:latest"
                }
            }
        }
        
        stage('Security Scan') {
            steps {
                sh """
                    trivy image --severity HIGH,CRITICAL \
                        --exit-code 0 \
                        --format table \
                        ${ECR_REPOSITORY}:${IMAGE_TAG}
                    
                    echo "Security scan completado"
                """
            }
        }
        
        stage('Push to ECR') {
            steps {
                script {
                    sh """                
                        echo "=== AWS ECR PUSH ==="
                        echo ""
                        
                        aws ecr get-login-password --region ${AWS_REGION} | \
                        docker login \
                            --username AWS \
                            --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                        
                        echo "Autenticación exitosa con ECR"
                        echo ""
                        
                        echo "=== Tags creados ==="
                        docker tag ${ECR_REPOSITORY}:${IMAGE_TAG} ${ECR_URI}:${IMAGE_TAG}
                        docker tag ${ECR_REPOSITORY}:${IMAGE_TAG} ${ECR_URI}:latest
                        
                        echo "  ${ECR_REPOSITORY}:${IMAGE_TAG} → ${ECR_URI}:${IMAGE_TAG}"
                        echo "  ${ECR_REPOSITORY}:${IMAGE_TAG} → ${ECR_URI}:latest"
                        echo ""
                        
                        echo "=== Subiendo imágenes a ECR ==="
                        docker push ${ECR_URI}:${IMAGE_TAG}
                        docker push ${ECR_URI}:latest
                        
                        echo ""
                        echo "Push exitoso"
                        echo "Imágenes disponibles en:"
                        echo "   ${ECR_URI}:${IMAGE_TAG}"
                        echo "   ${ECR_URI}:latest"
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo "Pipeline ${currentBuild.fullDisplayName} completado"
            cleanWs()
        }
        success {
            echo "Pipeline exitoso"
        }
        failure {
            echo "Pipeline falló"
        }
    }
}