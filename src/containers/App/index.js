import {bindActionCreators} from 'redux';
import {connect} from 'react-redux';
import * as InductionState from '../../reducers/induction/inductionReducer';
import React, {Component} from 'react';
import styles from './styles';
import CodeInputSelector from '../../components/CodeInputSelector'

import {
    StyleSheet,
    View,
    Text,
    TouchableHighlight,
    Image
} from 'react-native';

/**
 * ## App class
 *
 */
class App extends Component {

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
              <Text style={styles.messageBoxBodyText}>Welcome to OWAL. Enter an invite code or scan a QR code.</Text>
            </View>
          </View>
          <CodeInputSelector onSelect={this.props.actions.setInviteCode}/>
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
