import React, {Component, PropTypes} from 'react';
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
import {Actions} from 'react-native-router-flux';
import _ from 'lodash';

class QRCodeScreen extends Component {
  constructor(props) {
    super(props);
    this._onBarCodeRead = _.once(this._onBarCodeRead.bind(this));
  }
  _onBarCodeRead(result) {
    (Platform.OS === 'ios') ? VibrationIOS.vibrate() : Vibration.vibrate();
    this.props.onSelect(result.data);
  }

  _onCancel() {
    Actions.pop();
  }

  render() {
    return (
        <Camera onBarCodeRead={this._onBarCodeRead} style={styles.camera}>
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

QRCodeScreen.propTypes = {
  onSelect: PropTypes.func.isRequired,
};

export default QRCodeScreen;
