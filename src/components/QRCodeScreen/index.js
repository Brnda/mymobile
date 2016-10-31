import React, {Component, PropTypes} from 'react';
import {
    StyleSheet,
    View,
    Text,
    Platform,
    Vibration,
    VibrationIOS,
    TouchableOpacity,
    Alert
} from 'react-native';
import Camera from 'react-native-camera';
import styles from './styles';
import {Actions} from 'react-native-router-flux';
import * as InductionState from '../../reducers/induction/inductionReducer'
import {connect} from 'react-redux';
import Orientation from 'react-native-orientation';

class QRCodeScreen extends Component {
  constructor(props) {
    super(props);
    this.state = {read: false};
    this._onBarCodeRead = this._onBarCodeRead.bind(this);
  }

  componentWillMount() {
    Orientation.lockToPortrait();
  }

  _onBarCodeRead(result) {
    if(!this.state.read) {
      (Platform.OS === 'ios') ? VibrationIOS.vibrate() : Vibration.vibrate();
      this.props.onSelect(result.data);
      this.setState({read: true});
    }
  }

  _onCancel() {
    Actions.pop();
  }

  _resetErrorAlert() {
    this.props.dispatch(InductionState.resetInviteError());
    this.setState({read: false});
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
          {this.props.error &&
          Alert.alert(
              'Error',
              this.props.error,
              [{text: 'OK', onPress: () => this._resetErrorAlert() }])
          }
        </Camera>
    )
  }
}

QRCodeScreen.propTypes = {
  onSelect: PropTypes.func.isRequired,
};

function mapStateToProps(state){
  return {
    error: state.induction.get('ERROR')
  }
}
export default connect(mapStateToProps)(QRCodeScreen);
