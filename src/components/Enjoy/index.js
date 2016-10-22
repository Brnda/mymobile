import React, {Component} from 'react';
import {
    StyleSheet,
    View,
    Text,
    StatusBar,
    AsyncStorage
} from 'react-native';
import {connect} from 'react-redux';
import styles from './styles';
import InductionHeader from '../../components/InductionHeader';
import {Actions} from 'react-native-router-flux';
import {SKIP_INDUCTION_KEY, USER_TOKEN} from '../../lib/constants';

class Enjoy extends Component {

   async _setCompletionFlag() {
    try {
      await AsyncStorage.setItem(SKIP_INDUCTION_KEY, "true");
      await AsyncStorage.setItem(USER_TOKEN, this.props.token);
    } catch (error) {
      console.error(`We could not update the Persistant store.`);
    }

     const value = await AsyncStorage.getItem(SKIP_INDUCTION_KEY);
     console.log(`<>value has been set${value}`);
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

const mapStateToProps = (state) => {
  return {
    token: state.induction.get('SESSION_TOKEN')
  }
}

export default connect(mapStateToProps)(Enjoy);

