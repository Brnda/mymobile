import React, {Component} from 'react';
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

import {Actions} from 'react-native-router-flux';

class TextInviteCodeScreen extends Component {

  constructor(props) {
    super(props);
    this.state = {
      inviteCode: 'Enter invite code'
    };
  }

  _onCancel() {
    Actions.pop();
  }

  _onEnter() {
    // bring up spinner
    console.log("User typed invite code: " + this.state.inviteCode);
    console.log("Going to: " + this.props.onSelect);
    this.props.onSelect(this.state.inviteCode);
  }

  render() {
    return (
        <View style={styles.container}>
          <View>
            <Image
                source={{uri: 'http://owal.io/wp-content/uploads/2016/04/Screen-Shot-2016-04-17-at-7.22.29-PM.png'}}
                style={styles.logo}/>
          </View>
          <View style={styles.messageBoxContainer}>
            <View style={styles.messageBox}>
              <Text style={styles.messageBoxBodyText}>Please enter your invite code below.</Text>
            </View>
          </View>
          <View style={styles.inputcontainer}>
            <TextInput style={styles.input} onChangeText={(text)=>this.setState({inviteCode: text})}
                       value={this.state.inviteCode}/>
            <TouchableOpacity
                style={styles.enterButton}
                onPress={()=>this._onEnter()}
                underlayColor='#dddddd'>
              <Text style={styles.enterButtonText}>Verify</Text>
            </TouchableOpacity>
          </View>
          <View style={styles.cancelButton}>
            <TouchableOpacity onPress={this._onCancel}>
              <Text style={styles.cancelButtonText}>Cancel</Text>
            </TouchableOpacity>
          </View>
        </View>
    )
  }
}

export default TextInviteCodeScreen;
