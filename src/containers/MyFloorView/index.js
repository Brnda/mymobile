import React, {Component, PropTypes} from 'react';
import {View, Text} from 'react-native';
import styles from './styles';
import VideoController from '../../components/VideoController';
var VideoControllerManager = require('NativeModules').VideoControllerManager;

class MyFloor extends Component {
  componentWillMount() {
    VideoControllerManager.setURI(this.props.uri, this.props.title);
  }

  render() {
    return (
        <VideoController/>
    );
  }
}

MyFloor.propTypes = {
  uri: PropTypes.string.isRequired,
  title: PropTypes.string.isRequired
};

export default MyFloor;