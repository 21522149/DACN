pipeline {
    agent any
    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        AWS_ACCOUNT_ID = credentials('AWS_ACCOUNT_ID')
        AWS_DEFAULT_REGION = 'us-east-1'
        REPO_PREFIX = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/"
        GIT_REPO="DACN"
    }
    stages {
        stage("Cleaning Workspace") {
            steps {
                cleanWs()
            }
        }
        stage("Checkout from git") {
            steps {
                git credentialsId: 'github', url: 'https://github.com/21522149/DACN.git', branch: 'main'
            }
        }
        stage("Sonarqube Analysis") {
            steps {
                dir('src'){ 
                    withSonarQubeEnv('sonar-server') { 
                        bat '''
                            "%SCANNER_HOME%\\bin\\sonar-scanner.bat" -D"sonar.projectKey=Multi-microservice-deployment" -D"sonar.sources=." -D"sonar.host.url=http://localhost:9000" -D"sonar.token=squ_e42bdcfe7ed16035528bae376849cd55b1cbd183" -D"sonar.exclusions=**/*.java"
                        '''
                    }
                }
            }
        }
        stage('Quality Check') {
            steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'sonar-token' 
                }
            }
        }
        stage('OWASP Dependency-Check Scan') {
            steps {
                dir('src') {
                    dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'DP-Check'
                    dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
                }
            }
        }
        stage('Trivy File Scan') {
            steps {
                dir('src') {
                    bat 'trivy fs . > trivyfs.txt' 
                }
            }
        }
        stage("Docker image build and ECR push"){
            steps{
                script{
                    dir('Scripts'){
                            bat 'make-docker.sh'
                        }
                }
            }
        }
        stage("Update Deployment file"){
            steps{
                withCredentials([usernamePassword(credentialsId: 'github', usernameVariable: 'GIT_USER_NAME', passwordVariable: 'GITHUB_TOKEN')]) {
                    dir('Scripts'){
                        bat 'make-release.sh' 
                    }
                }
            }
        }
    }
}
