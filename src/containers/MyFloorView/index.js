import React, {Component, PropTypes} from 'react';
import {View, Text} from 'react-native';
import VideoController from '../../components/VideoController';
var VideoControllerManager = require('NativeModules').VideoControllerManager;

class MyFloor extends Component {
  componentWillMount() {
    console.log(`URL ${this.props.uri}`);
    VideoControllerManager.setURI(this.props.uri, this.props.title);
  }

  render() {
    return (
      <View style={{flex: 1, backgroundColor: 'green'}}>
          <VideoController/>
      </View>
    );

  }
}

MyFloor.propTypes = {
  uri: PropTypes.string.isRequired,
  title: PropTypes.string.isRequired
};

export default MyFloor;