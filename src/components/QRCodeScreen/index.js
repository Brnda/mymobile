import React, {Component} from 'react';
import {
    StyleSheet,
    View,
    Text,
    Platform,
    Vibration,
    VibrationIOS,
    TouchableOpacity
} from 'react-native';
import Camera from 'react-native-camera';
import styles from './styles';
import { Actions } from 'react-native-router-flux';

class QRCodeScreen extends Component {
  _onBarCodeRead(result) {
    var $this = this;

    setTimeout(function () {
      (Platform.OS === 'ios') ? VibrationIOS.vibrate() : Vibration.vibrate();
      $this.props.onSelect(result.data);
    }, 1000);
  }

  _onCancel() {
    Actions.pop();
  }

  render() {
    return (
        <Camera onBarCodeRead={this._onBarCodeRead.bind(this)} style={styles.camera}>
          <View style={styles.rectangleContainer}>
            <View style={styles.rectangle}/>
          </View>
          <View style={styles.cancelButton}>
            <TouchableOpacity onPress={this._onCancel}>
              <Text style={styles.cancelButtonText}>Cancel</Text>
            </TouchableOpacity>
          </View>
        </Camera>
    )
  }
}

export default QRCodeScreen;
