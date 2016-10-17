import React, {PropTypes} from 'react';
import TabIcon from '../TabIcon';

const TabIconBuilding = (props) => (
  <TabIcon iconName="buildingEntrance" selected={props.selected}/>
);

TabIconBuilding.propTypes =  {
  selected: PropTypes.bool
};

export default TabIconBuilding;