import {bindActionCreators} from 'redux';
import {connect} from 'react-redux';
import * as InductionState from '../../reducers/induction/inductionReducer';
import React, {Component} from 'react';
import styles from './styles';
import CodeInputSelector from '../../components/CodeInputSelector';
import InductionHeader from '../../components/InductionHeader';

import {
    View,
    Text,
    TouchableHighlight,
    Image,
    StatusBar
} from 'react-native';

/**
 * ## App class
 *
 */
class App extends Component {

  render() {
    return (
        <View style={styles.container}>
          <StatusBar hidden={true} />
          <InductionHeader />
          <View style={styles.messageBoxContainer}>
            <Text style={styles.messageBoxBodyText}>Enter an invite code or scan a QR code to continue.</Text>
          </View>
          <CodeInputSelector onSelect={this.props.actions.checkInviteCode}/>
        </View>
    )
  }
}

function mapDispatchToProps(dispatch) {
  return {
    actions: bindActionCreators({...InductionState}, dispatch),
    dispatch
  }
}

export default connect(null, mapDispatchToProps)(App);
