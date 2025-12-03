pipeline {
    agent {
        label 'docker&&linux'
    }
    
    environment {
        // Variables de AWS ECR
        AWS_ACCOUNT_ID = '851725481871'
        AWS_REGION = 'us-east-1'
        ECR_REPOSITORY = 'python-ci-cd-demo'
        IMAGE_TAG = "${env.BUILD_ID}"
        
        // Tags para diferentes entornos
        DEV_TAG = "1.0.0-dev-${env.BUILD_ID}"
        STAGING_TAG = "1.0.0-staging-${env.BUILD_ID}"
        PROD_TAG = "1.0.0"
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
                    // Verificar Docker
                    sh 'docker --version'
                    
                    // Configurar AWS CLI (si está disponible)
                    sh '''
                        aws --version || echo "AWS CLI no instalado"
                    '''
                }
            }
        }
        
        stage('Run Tests') {
            steps {
                sh '''
                    python -m pytest tests/ -v --cov=app --cov-report=xml
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
                    python -m py_compile app/*.py
                    echo "Linting básico completo"
                '''
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    // Build multi-stage
                    sh "docker build -t ${ECR_REPOSITORY}:${IMAGE_TAG} ."
                    
                    // Tag adicional
                    sh "docker tag ${ECR_REPOSITORY}:${IMAGE_TAG} ${ECR_REPOSITORY}:latest"
                }
            }
        }
        
        stage('Security Scan') {
            steps {
                script {
                    // Escanear imagen con Trivy (si está instalado)
                    sh '''
                        trivy --version && \
                        trivy image --exit-code 0 --severity HIGH,CRITICAL ${ECR_REPOSITORY}:${IMAGE_TAG} || \
                        echo "Trivy no disponible, saltando security scan"
                    '''
                }
            }
        }
        
        stage('Push to ECR') {
    steps {
        script {
            withCredentials([
                string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY'),
                string(credentialsId: 'aws-account-id', variable: 'AWS_ACCOUNT_ID')
            ]) {
                sh '''
                    # Configurar AWS CLI temporalmente
                    export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
                    export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
                    export AWS_DEFAULT_REGION=us-east-1
                    
                    # Login a ECR
                    aws ecr get-login-password | docker login \
                        --username AWS \
                        --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com
                    
                    # Tag y push
                    docker tag python-app:${BUILD_ID} \
                        ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/python-app:${BUILD_ID}
                    
                    docker push ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/python-app:${BUILD_ID}
                '''
            }
        }
    }
}
        
        
    }
    
    post {
        always {
            echo "Pipeline ${currentBuild.fullDisplayName} completado"
            cleanWs() // Limpiar workspace
        }
        success {
            echo "Pipeline exitoso"
            // Notificación opcional
        }
        failure {
            echo "Pipeline falló"
            // Notificación de fallo
        }
    }
}