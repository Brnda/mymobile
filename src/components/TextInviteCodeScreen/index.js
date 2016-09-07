import React, {Component, PropTypes} from 'react';
import {
    StyleSheet,
    View,
    Text,
    TextInput,
    Image,
    Platform,
    Vibration,
    VibrationIOS,
    TouchableOpacity,
    TouchableHighlight
} from 'react-native';
import styles from './styles';

class TextInviteCodeScreen extends Component {
  constructor(props) {
    super(props);
    this.state = {
      continue: false
    };
  }

  _onPressContinueButton() {
    this.props.onSelect(this.state.text);
  }

  _onCodeEntered(text) {
    if (text.length > 0) {
      this.setState({continue: true, text});
    } else {
      this.setState({continue: false, text});
    }
  }

  render() {
    return (
        <View style={styles.container}>
          <View>
            <Image source={require('../../containers/App/img/logo_icon_only.png')} style={styles.logo}/>
          </View>
          <View style={styles.header}>
            <Text style={styles.headerText}>Enter your invite code</Text>
          </View>
          <View style={styles.containerInputText}>
            <TextInput ref="inviteCode" style={styles.inviteTextInput} onChangeText={this._onCodeEntered.bind(this)}/>
          </View>
          {this.state.continue &&
            <TouchableOpacity style={styles.continueButton} onPress={this._onPressContinueButton.bind(this)}>
              <Text style={styles.continueButtonText}>CONTINUE</Text>
            </TouchableOpacity>
          }
        </View>
    );
  }
}

TextInviteCodeScreen.propTypes = {
  onSelect: PropTypes.func.isRequired,
};

export default TextInviteCodeScreen;
