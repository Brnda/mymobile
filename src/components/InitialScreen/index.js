import React, {Component} from 'react';
import {
    StyleSheet,
    View,
    Text,
    StatusBar,
    AsyncStorage,
    ActivityIndicator
} from 'react-native';
import {connect} from 'react-redux';
import styles from './styles';
import InductionHeader from '../../components/InductionHeader';
import {Actions} from 'react-native-router-flux';
import {SKIP_INDUCTION_KEY, USER_TOKEN} from '../../lib/constants';
import Orientation from 'react-native-orientation';

class Enjoy extends Component {
  state = {animating: true};

  _setCompletionFlag() {
    AsyncStorage.getItem(USER_TOKEN).then((token) => {
      this.setState({animating: false});

      if(token) {
        Actions.main(); //We could dispatch an action here.
      } else {
        Actions.app();
      }
    });
  }

  componentDidMount() {
    Orientation.lockToPortrait();
    setTimeout(() => { this._setCompletionFlag(); }, 2000);
  }

  render() {
    return (
        <View style={styles.container}>
          <StatusBar hidden={true}/>
          <InductionHeader style={styles.logo}/>
          <View style={styles.header}>
            <ActivityIndicator
              animating={this.state.animating}
              style={[styles.centering, {height: 80}]}
              size="large"
            />
            <Text style={styles.headerText}>Starting things up!</Text>
          </View>
        </View>
    )
  }
}

export default Enjoy;

