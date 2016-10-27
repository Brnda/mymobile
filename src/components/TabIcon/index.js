import React, {PropTypes} from 'react';
import {
    Image
} from 'react-native';

const TabIcon = (props) => {
  switch(props.iconName) {
    case 'buildingEntrance':
      return <Image source={require('../../icons/buildingW.png')} />;
    case 'message':
      return <Image source={require('../../icons/messageW.png')} />;
    case 'profile':
      return <Image source={require('../../icons/profileW.png')} />;
    default:
      return null;
  }
};

TabIcon.propTypes =  {
  iconName: PropTypes.string.isRequired
};

export default TabIcon;