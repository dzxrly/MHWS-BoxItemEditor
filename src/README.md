# 部分文件来源

1. 同时带有`物品Guid`与`FixedID`的文件为[ItemData.json](./data/ItemData.json)，来自
   `natives/STM/GameDesign/Common/Item/ItemData.user.3`
   ，通过[RETool](https://github.com/mhvuze/MonsterHunterWildsModding/raw/main/files/REtool.exe)
   或[ree-pak-rs](https://github.com/eigeen/ree-pak-rs/releases)获取；
2. 同时带有`物品Guid`与`I18N翻译名称`的文件为[.Item.msg.23.csv](./data/Item.msg.23.csv)，来自
   `natives/STM/GameDesign/Text/Excel_Data/Item.msg.23`
   ，需要使用RE引擎文本转换器——[REMSG_Converter](https://github.com/dtlnor/REMSG_Converter)转换文本文件获取。
