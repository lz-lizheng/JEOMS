create
    definer = jusre4557wkn@`%` procedure stock_upload_strategy_repeat_warehouse()
begin
    #该变量用于标识是否还有数据需遍历
    DECLARE flag INT DEFAULT 0;

    DECLARE v_id varchar(50) default '';

    #查询出需要遍历的数据集合，#获取到当前库存上传配置的虚拟仓ID和虚拟仓名称
    DECLARE strategy_id CURSOR FOR SELECT stock_upload_strategy_id as strategy_id
                                   FROM oms_stock_upload_strategy
                                   where stock_upload_strategy_name = '烽火先锋运动专营店-拼多多';
 #查询是否有下一个数据，没有将标识设为1，相当于hasNext
    DECLARE continue HANDLER FOR NOT FOUND set flag := 1;
    OPEN strategy_id;
    FETCH strategy_id INTO v_id;
    WHILE flag != 1
        do
           set @v_virtual_warehouse_id = (SELECT substring_index(substring_index((SELECT virtualWarehouseId
                                                                                    FROM (select substring(
                                                                                                         JSON_EXTRACT(setting_json, '$.warehouses[*].virtualWarehouseId'),
                                                                                                         3,
                                                                                                         LENGTH(
                                                                                                                 JSON_EXTRACT(setting_json, '$.warehouses[*].virtualWarehouseId')) -
                                                                                                         4)
                                                                                                     as virtualWarehouseId
                                                                                          from oms_stock_upload_strategy
                                                                                          where stock_upload_strategy_id = v_id
                                                                                         ) a
                                                                                   ), '", "', help_topic_id + 1),
                                                                   '", "', - 1) as virtualWarehouseId
                                            FROM mysql.help_topic
                                            where help_topic_id < (
                                                select (length((select substring(
                                                                               JSON_EXTRACT(setting_json, '$.warehouses[*].virtualWarehouseId'),
                                                                               3,
                                                                               LENGTH(
                                                                                       JSON_EXTRACT(setting_json, '$.warehouses[*].virtualWarehouseId')) -
                                                                               4)
                                                                           as virtualWarehouseId
                                                                from oms_stock_upload_strategy
                                                                where stock_upload_strategy_id = v_id)) -
                                                        length(replace(
                                                                (select substring(
                                                                                JSON_EXTRACT(setting_json, '$.warehouses[*].virtualWarehouseId'),
                                                                                3,
                                                                                LENGTH(
                                                                                        JSON_EXTRACT(setting_json, '$.warehouses[*].virtualWarehouseId')) -
                                                                                4)
                                                                            as virtualWarehouseId
                                                                 from oms_stock_upload_strategy
                                                                 where stock_upload_strategy_id = v_id), '", "', ''))) /
                                                       4 + 1
                                            )
                                            group by virtualWarehouseId
                                            having count(virtualWarehouseId) > 1
           );


            FETCH strategy_id INTO v_id;
        end while;
    #关闭游标
    close strategy_id;


end;

