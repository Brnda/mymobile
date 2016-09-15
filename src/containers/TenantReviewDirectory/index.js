import React, {Component} from 'react';
import {
    View,
    Text,
    TextInput,
    Keyboard,
    Dimensions,
    ScrollView,
    TouchableOpacity
} from 'react-native';
import styles from './styles'
import InductionHeader from '../../components/InductionHeader'

class TenantReviewDirectory extends Component {
  constructor(props) {
    super(props);
    this.state = {
      continue: false
    };
    this._onPressContinueButton.bind(this);
  }

  componentWillMount() {
    this.keyboardDidShowListener =
      Keyboard.addListener('keyboardDidShow', this.keyboardDidShow.bind(this));
    this.keyboardDidHideListener =
      Keyboard.addListener('keyboardDidHide', this.keyboardDidHide.bind(this));
  }

  componentWillUnmount() {
    this.keyboardDidHideListener.remove();
    this.keyboardDidShowListener.remove();
  }

  keyboardDidShow(e) {
    this._scroller.scrollTo({y: 120});
    this.setState({scroll: false});
  }

  keyboardDidHide(e) {
    this._scroller.scrollTo({y: 0});
    this.setState({scroll: true});
  }

  _onFirstNameEntered(firstName) {
    if (firstName && firstName.length > 0) {
      this.setState({continue: true, firstName});
    } else {
      this.setState({continue: false, firstName});
    }
  }

  _onLastNameEntered(lastName) {
    this.setState({lastName});
  }

  _onPressContinueButton() {
    //TODO: Wire this up to the home screen
  }

  render() {
    return (
        <View style={styles.container}>
          <ScrollView style={{flex: 3}} scrollEnabled={this.state.scroll}
            ref={(scroller) => this._scroller = scroller}>
            <InductionHeader/>
            <View style={styles.header}>
              <Text style={styles.headerText}>
                Would you like to use your name in the building directory?
              </Text>
            </View>

            <View style={styles.containerInputText}>
              <TextInput placeholder="First Name" onChangeText={this._onFirstNameEntered.bind(this)}
                         placeholderTextColor="rgba(240, 255, 255,0.3)" style={styles.inviteTextInput}/>
            </View>
            <View style={styles.containerInputText}>
              <TextInput placeholder="Last Name" onChangeText={this._onLastNameEntered.bind(this)}
                         placeholderTextColor="rgba(240, 255, 255,0.3)" style={styles.inviteTextInput}/>
            </View>
            {this.state.continue &&
            <TouchableOpacity style={styles.continueButton} onPress={this._onPressContinueButton}>
              <Text style={styles.continueButtonText}>CONTINUE</Text>
            </TouchableOpacity>
            }
          </ScrollView>
          <View style={styles.tenantSkipButton}>
            <TouchableOpacity style={styles.tenantButton} onPress={this._onPressContinueButton}>
              <Text style={styles.tenantButtonText}>Skip</Text>
            </TouchableOpacity>
          </View>
        </View>
    );
  }
}

export default TenantReviewDirectory;