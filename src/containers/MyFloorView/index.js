import React, {Component, PropTypes} from 'react';
import {View, Text, TouchableWithoutFeedback, findNodeHandle} from 'react-native';
import VideoController from '../../components/VideoController';
var VideoControllerManager = require('NativeModules').VideoControllerManager;

class MyFloor extends Component {
  _handlePress() {
    console.log(`uri is ${this.props.uri} ${findNodeHandle(this.refs.vamos)}`);
    VideoControllerManager.play(findNodeHandle(this.refs.vamos));
  }

  _handlePress2() {
    console.log(`uri is ${this.props.uri} ${findNodeHandle(this.refs.vamos2)}`);
    VideoControllerManager.play(findNodeHandle(this.refs.vamos2));
  }

  _handlePress3() {
    console.log(`uri is ${this.props.uri} ${findNodeHandle(this.refs.vamos3)}`);
    VideoControllerManager.play(findNodeHandle(this.refs.vamos3));
  }

  render() {
    return (
      <View style={{flex: 1, backgroundColor: 'green'}}>
        <TouchableWithoutFeedback onPress={this._handlePress.bind(this)}>
          <VideoController
            ref="vamos"
            uri={this.props.uri}
            style={{flex: 1, margin: 3}} />
        </TouchableWithoutFeedback>
        <TouchableWithoutFeedback onPress={this._handlePress2.bind(this)}>
          <VideoController
              ref="vamos2"
              uri="rtsp://prod-vpn.p.owal.io:28708/proxyStream"
              style={{flex: 1, margin: 3}} />
        </TouchableWithoutFeedback>
        <TouchableWithoutFeedback onPress={this._handlePress3.bind(this)}>
          <VideoController
              ref="vamos3"
              uri="rtsp://prod-vpn.p.owal.io:28714/proxyStream"
              style={{flex: 1, margin: 3}} />
        </TouchableWithoutFeedback>
        {/*  rtsp://prod-vpn.p.owal.io:28708/proxyStream */}
        {/*  rtsp://prod-vpn.p.owal.io:28714/proxyStream */}
        <View style={{flex: 3, backgroundColor: 'powderblue'}}><Text>HEY YA!</Text></View>
      </View>
    );
  }
}

MyFloor.propTypes = {
  uri: PropTypes.string.isRequired,
  title: PropTypes.string.isRequired
};

export default MyFloor;