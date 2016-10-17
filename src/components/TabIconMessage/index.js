import React, {PropTypes} from 'react';
import TabIcon from '../TabIcon';

const TabIconMessage = (props) => (
  <TabIcon iconName="message" selected={props.selected}/>
);

TabIconMessage.propTypes =  {
  selected: PropTypes.bool
};

export default TabIconMessage;