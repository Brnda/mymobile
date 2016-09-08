import React from 'react';
import {
    View,
    Image
} from 'react-native';
import styles from './styles';

const InductionHeader = (props) => (
    <View>
      <Image source={require('./img/logo_icon_only.png')} style={props.imageStyle?props.imageStyle:styles.logo}/>
    </View>
);

export default InductionHeader;