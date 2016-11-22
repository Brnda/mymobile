import React from 'react';
import {View, Text, Image} from 'react-native';
import styles from './styles';


const ChatScreen = (props) => {
  return (
    <View style={styles.container}>
      <Text style={styles.message}>Chat view coming...</Text>
      <Image source={require('./img/soon__.jpg')} style={styles.soon}/>
    </View>
  );
};

export default ChatScreen;