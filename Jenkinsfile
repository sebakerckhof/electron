#!/usr/bin/env groovy

@Library('jenkins-scripts@develop') _

pipeline {
  agent {
    docker {
      image 'docker-enp.bin.cloud.barco.com/edu/electron-ci:1.0.0'
      label 'linux-slave-edu'
      args '--group-add 999 -v /var/run/docker.sock:/var/run/docker.sock -v /etc/group:/etc/group:ro -v /etc/passwd:/etc/passwd:ro -v /home/jenkins/.docker:/home/jenkins/.docker:ro'
      reuseNode true
      alwaysPull false
    }
  }

  options {
    buildDiscarder(logRotator(numToKeepStr:'20'))
    disableConcurrentBuilds()
    timeout(time:2, unit: 'HOURS')
    timestamps()
  }

  environment {
    CI = 'true'
    DOCKER_REGISTRY   = 'dockerdev-enp.bin.cloud.barco.com'
    DOCKER_REPOSITORY = 'edu'
    DOCKER_NAME       = 'blue'
    SLACK_AUTH_TOKEN = credentials('EDU_SLACK_APIKEY')
    SLACK_BASEURL    = credentials('EDU_SLACK_BASE_URL')
    SLACK_WORKSPACE  = credentials('EDU_SLACK_WORKSPACE')
    SLACK_CHANNEL    = credentials('EDU_SLACK_CHANNEL')
    ARTIFACTORY_ACCOUNT = credentials('EDU_ARTIFACTORY_ACCOUNT')
    ARTIFACTORY_URL     = credentials('TF_VAR_ARTIFACTORY_URL')
  }

  stages {
    stage ('Start') {
      steps {
        sh '''
          source `which gitenv`
          env
        '''
        script {
          notifyStash('STARTED')
        }
      }
    }

    stage ('Install dependencies') {
      when {
        not {
          anyOf {
            buildingTag()
            branch 'production'
          }
        }
      }
      parallel {
        stage('NPM') {
          steps {
            sh '''
              cd projects/edu
              meteor npm install --ignore-scripts
            '''
          }
        }
        stage('Meteor cache') {
          steps {
            sh '''
              curl -s -f -u${ARTIFACTORY_ACCOUNT} "${ARTIFACTORY_URL}/www-cache/${METEOR_CACHE_FILE}" | tar -xzC $HOME 2> /dev/null || touch $METEOR_CACHE_FILE
            '''
          }
        }
      }
    }

    stage ('Check code style') {
      when {
        not {
          anyOf {
            buildingTag()
            branch 'production'
          }
        }
      }
      parallel {
        stage('JS') {
          steps {
            sh '''
              cd projects/edu
              meteor npm run lint:js
            '''
          }
        }
        stage('SCSS') {
          steps {
            sh '''
              cd projects/edu
              meteor npm run lint:css
            '''
          }
        }
        stage('PyLint') {
          steps {
            sh '''
              flake8 e2e
            '''
          }
        }
      }
    }

  }

  post {
    always {
      script {
        notifyStash(currentBuild.result)
        notifySlack2(currentBuild.result,
            "${SLACK_BASEURL}",
            "${SLACK_CHANNEL}",
            "${SLACK_WORKSPACE}",
            "${SLACK_AUTH_TOKEN}",
            "SLACK_AUTH_TOKEN"
          )
      }
    }
  }
}
