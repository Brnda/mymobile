import React, {Component} from 'react';
import {
    View,
    Text,
    TouchableHighlight,
    Image
} from 'react-native';

import {Actions} from 'react-native-router-flux';

import styles from './styles';

class CodeInputSelector extends Component {
  _onChoose() {
    Actions.qrcodescreen({onSelect: this.props.onSelect});
  }

  _onChooseText() {
    Actions.textinvitecodescreen({onSelect: this.props.onSelect});
  }

  render() {
    return (
        <View style={styles.choiceBoxes}>
          <TouchableHighlight onPress={this._onChoose.bind(this)}>
            <View style={styles.qrCode}>
              <Image source={require('./img/qr_code.png')}/>
              <View style={styles.inviteLabel}>
                <Text style={styles.inviteText}>QR CODE</Text>
              </View>
            </View>
          </TouchableHighlight>
          <TouchableHighlight onPress={this._onChooseText.bind(this)}>
            <View style={styles.inviteCode}>
              <Image source={require('./img/invite_code.png')}/>
              <View style={styles.inviteLabel}>
                <Text style={styles.inviteText}>INVITE CODE</Text>
              </View>
            </View>
          </TouchableHighlight>
        </View>
    )
  }
}

export default CodeInputSelector;
