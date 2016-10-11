import React, {PropTypes} from 'react';
import TabIcon from '../TabIcon';

const TabIconProfile = (props) => (
  <TabIcon iconName="profile" selected={props.selected}/>
);

TabIconProfile.propTypes =  {
  selected: PropTypes.bool
};

export default TabIconProfile;