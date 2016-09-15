import React, {Component} from 'react';
import {
    StyleSheet,
    View,
    Text,
    StatusBar
} from 'react-native';
import styles from './styles';
import InductionHeader from '../../components/InductionHeader';
import {Actions} from 'react-native-router-flux';

class TenantReviewLastQuestion extends Component {
  componentDidMount() {
    setTimeout(function(){ Actions.home(); }, 3000);
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

export default TenantReviewLastQuestion;

