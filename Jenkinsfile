
pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        skipDefaultCheckout(true)
        timeout(time: 30, unit: 'MINUTES')
    }

    environment {
        COMPOSE_PROJECT_NAME = 'blood-donation-management-system'

        DB_PASSWORD = credentials('blood-db-password')
        MYSQL_ROOT_PASSWORD = credentials('blood-mysql-root-password')
        JWT_SECRET_KEY = credentials('blood-jwt-secret')

        FRONTEND_PORT = '8095'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm

                sh '''
                    echo "Repository checked out successfully"
                    git branch --show-current
                    git log -1 --oneline
                    test -f backend/Dockerfile
                    test -f frontend/Dockerfile
                    test -f frontend/nginx.conf
                    test -f docker-compose.yml
                    test -f database/schema.sql
                    test -f database/seed.sql
                '''
            }
        }

        stage('Prepare Environment') {
            steps {
                sh '''
                    set +x
                    umask 077

                    printf '%s\\n' \
                      "DB_PASSWORD=$DB_PASSWORD" \
                      "MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD" \
                      "JWT_SECRET_KEY=$JWT_SECRET_KEY" \
                      "FRONTEND_PORT=$FRONTEND_PORT" > .env

                    echo "Deployment environment prepared"
                '''
            }
        }

        stage('Validate Docker Compose') {
            steps {
                sh '''
                    docker --version
                    docker compose version
                    docker compose config --quiet
                    echo "Docker Compose configuration is valid"
                '''
            }
        }

        stage('Build Docker Images') {
            steps {
                sh '''
                    docker compose build
                '''
            }
        }

        stage('Backend Tests') {
            steps {
                sh '''
                    docker compose up -d mysql

                    echo "Waiting for MySQL health check..."
                    for i in $(seq 1 60); do
                        STATUS=$(docker inspect \
                          --format='{{.State.Health.Status}}' \
                          blood-donation-mysql 2>/dev/null || true)

                        if [ "$STATUS" = "healthy" ]; then
                            break
                        fi

                        sleep 5
                    done

                    STATUS=$(docker inspect \
                      --format='{{.State.Health.Status}}' \
                      blood-donation-mysql)

                    if [ "$STATUS" != "healthy" ]; then
                        docker compose logs mysql
                        echo "MySQL did not become healthy"
                        exit 1
                    fi

                    docker compose run --rm -e PYTHONPATH=/app backend python -m pytest -q tests/test_security.py
                '''
            }
        }

        stage('Deploy Application') {
            steps {
                sh '''
                    docker compose up -d --build
                    docker compose ps
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    echo "Checking frontend through the Docker host..."

                    for i in $(seq 1 30); do
                        if curl -fsS \
                          http://host.docker.internal:8095/ \
                          -o /dev/null; then
                            echo "Frontend HTTP check passed"
                            break
                        fi

                        if [ "$i" -eq 30 ]; then
                            echo "Frontend HTTP check failed"
                            docker compose ps
                            docker compose logs --tail=100
                            exit 1
                        fi

                        sleep 5
                    done

                    docker compose ps
                    echo "Deployment verification completed"
                '''
            }
        }
    }

    post {
        success {
            echo 'Blood Donation Management System deployed successfully.'
            echo 'Frontend: http://localhost:8085'
        }

        failure {
            echo 'Pipeline failed. Inspect the failed stage and container logs.'
            sh 'docker compose logs --tail=100 || true'
        }

        always {
            sh 'rm -f .env'
            echo 'Temporary deployment environment file removed.'
        }
    }
}
