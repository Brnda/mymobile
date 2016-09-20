import React from 'react';
import {View, Text} from 'react-native';
import styles from './styles';

export default Home = () => {
  return (
      <View style={styles.container}>
        <View style={styles.header}><Text>SPACES</Text></View>
        <View style={styles.row}>
          <View style={{backgroundColor: 'blue', flex: 1, margin: 20, alignItems: 'center'}}><Text>MAIN ENTRANCE</Text></View>
          <View style={{backgroundColor: 'green', flex: 1, margin: 20, alignItems: 'center'}}><Text>MY FLOOR</Text></View>
        </View>
        <View style={styles.row}>
          <View style={{backgroundColor: 'blue', flex: 1, margin: 20, alignItems: 'center'}}><Text>LAUNDRY</Text></View>
          <View style={{backgroundColor: 'green', flex: 1, margin: 20, alignItems: 'center'}}><Text>GYM</Text></View>
        </View>
        <View style={styles.row}>
          <View style={{backgroundColor: 'blue', flex: 1, margin: 20, alignItems: 'center'}}><Text>POOL</Text></View>
          <View style={{backgroundColor: 'green', flex: 1, margin: 20, alignItems: 'center'}}><Text>GARAGE</Text></View>
        </View>
      </View>
  );
}