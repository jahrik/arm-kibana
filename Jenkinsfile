#!/usr/bin/env groovy

node('armv7l') {

  try {

    stage('build') {
      deleteDir()
      checkout scm
      sh "make"
    }

    stage('push') {
      sh "make push"
    }

  } catch(error) {
    throw error

  } finally {
    deleteDir()

  }
}

node('ansible') {

  try {

    stage('scm') {
      deleteDir()
      checkout scm
    }

    stage('provision') {
      echo "ELASTICSEARCH_URL: elasticsearch-url"
      ansiColor('xterm') {
        ansiblePlaybook(
          playbook: 'playbook.yml',
          inventory: 'inventory.ini',
          colorized: true)
      }
    }

  } catch(error) {
    throw error

  } finally {
    deleteDir()
  }
}

node('manager') {

  try {

    stage('scm') {
      deleteDir()
      checkout scm
    }

    stage('deploy') {
      sh "make deploy"
    }

  } catch(error) {
    throw error

  } finally {
    deleteDir()
  }
}
