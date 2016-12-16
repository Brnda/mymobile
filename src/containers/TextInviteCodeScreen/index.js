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
    Alert
} from 'react-native';
import styles from './styles';
import {Actions} from 'react-native-router-flux';
import InductionHeader from '../../components/InductionHeader';
import {connect} from 'react-redux';
import * as InductionState from '../../reducers/induction/inductionReducer'
import Orientation from 'react-native-orientation';

class TextInviteCodeScreen extends Component {
  constructor(props) {
    super(props);
    this.state = {
      continue: false
    };
  }

  componentWillMount() {
    Orientation.lockToPortrait();
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

  _onPressBackButton() {
    Actions.pop();
  }

  render() {
    return (
        <View style={styles.container}>
          <TouchableOpacity style={styles.chevron} onPress={this._onPressBackButton}>
            <Image source={require('./img/left-chevron.png')} style={styles.chevronImg}/>
          </TouchableOpacity>
          <InductionHeader style={styles.logo}/>
          <View style={styles.header}>
            <Text style={styles.headerText}>Enter your invite code</Text>
          </View>
          <View style={styles.containerInputText}>
            <TextInput autoCapitalize='characters'
              returnKeyType={ 'done' }
              ref="inviteCode"
              style={styles.inviteTextInput}
              onChangeText={this._onCodeEntered.bind(this)}/>
          </View>
          {this.state.continue &&
          <TouchableOpacity style={styles.continueButton} onPress={this._onPressContinueButton.bind(this)}>
            <Text style={styles.continueButtonText}>CONTINUE</Text>
          </TouchableOpacity>
          }
          {this.props.error &&
            Alert.alert(
                'Error',
                this.props.error,
                [{text: 'OK', onPress: () => this.props.dispatch(InductionState.resetInviteError())}])
          }
        </View>
    );
  }
}

TextInviteCodeScreen.propTypes = {
  onSelect: PropTypes.func.isRequired,
};

function mapStateToProps(state) {
  return {
    error: state.induction.get('ERROR')
  }
}

export default connect(mapStateToProps)(TextInviteCodeScreen);
