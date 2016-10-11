import React, {Component} from 'react';
import {
    StyleSheet,
    View,
    Text,
    StatusBar,
    AsyncStorage
} from 'react-native';
import styles from './styles';
import InductionHeader from '../../components/InductionHeader';
import {Actions} from 'react-native-router-flux';
import {SKIP_INDUCTION_KEY} from '../../lib/constants';

class Enjoy extends Component {
   async _setCompletionFlag() {
    try {
      await AsyncStorage.setItem(SKIP_INDUCTION_KEY, "true");
    } catch (error) {
      console.error(`We could not update the Persistant store.`);
    }
  }
  componentDidMount() {
    this._setCompletionFlag();
    setTimeout(function(){ Actions.main(); }, 2000);
  }

  render() {
    return (
        <View style={styles.container}>
          <StatusBar hidden={true}/>
          <InductionHeader style={styles.logo}/>
          <View style={styles.header}>
            <Text style={styles.headerText}>Enjoy!</Text>
          </View>
        </View>
    )
  }
}

export default Enjoy;

