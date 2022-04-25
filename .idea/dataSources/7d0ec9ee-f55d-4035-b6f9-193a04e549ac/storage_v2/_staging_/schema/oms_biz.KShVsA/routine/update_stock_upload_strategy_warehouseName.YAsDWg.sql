create
    definer = jusre4557wkn@`%` procedure update_stock_upload_strategy_warehouseName()
begin
    DECLARE s_id varchar(10000) default '';
    DECLARE s_name varchar(16000) default '';
    DECLARE strategy_name varchar(50) default '';
    DECLARE v_store_name varchar(50) default '';


    DECLARE abnormal varchar(16000) default '';
    #该变量用于标识是否还有数据需遍历
    DECLARE flag INT DEFAULT 0;

    #查询出需要遍历的数据集合，#获取到当前库存上传配置的虚拟仓ID和虚拟仓名称
    DECLARE strategy_id CURSOR FOR SELECT stock_upload_strategy_name                                         as strategy_name,
                                          store_name                                                         as v_store_name,
                                          JSON_EXTRACT(setting_json, '$.warehouses[*].virtualWarehouseId')   as s_id,
                                          JSON_EXTRACT(setting_json, '$.warehouses[*].virtualWarehouseName') as s_name
                                   FROM oms_stock_upload_strategy;
    #查询是否有下一个数据，没有将标识设为1，相当于hasNext
    DECLARE continue HANDLER FOR NOT FOUND set flag := 1;

    #创建虚拟仓临时表
#     DROP table IF EXISTS oms_admin.oms_virtual_warehouse_tem;
#     CREATE TABLE oms_admin.oms_virtual_warehouse_tem
#     (
#         virtual_warehouse_id   bigint unsigned not null primary key,
#         virtual_warehouse_name VARCHAR(50)     NOT NULL
#
#     );
#     INSERT INTO oms_admin.oms_virtual_warehouse_tem (virtual_warehouse_id, virtual_warehouse_name)
#     select virtual_warehouse_id, virtual_warehouse_name
#     from oms_virtual_warehouse;


    # #     #虚拟仓数据条数
#     set @virtual_warehouse_num := (select count(1) from oms_virtual_warehouse);
#     #库存上传配置数据条数
#     set @stock_upload_strategy_num :=
#             (select count(1)
#              from oms_stock_upload_strategy
#              where stock_upload_strategy_name in ('拼多多童装-361度清桐专卖店', '抖音小店361度福建门店'));

    #打开游标
    OPEN strategy_id;
    FETCH strategy_id INTO strategy_name,v_store_name,s_id,s_name;
    WHILE flag != 1

        DO
            set @w_ids = '',@w_names = '';


            SET @i = 1;
            #截取掉前后 [""] 中括号
            set @w_ids := REPLACE(s_id, '["', '');
            set @w_ids := REPLACE(s_id, '"]', '');
            set @w_names := REPLACE(s_name, '["', '');
            set @w_names := REPLACE(s_name, '"]', '');
            #计算有多少逗号，需要遍历多少次
            SET @count = CHAR_LENGTH(s_id) - CHAR_LENGTH(REPLACE(s_id, ',', '')) + 1;


            WHILE @i <= @count
                DO
                    set @v_id := SUBSTRING_INDEX(SUBSTRING_INDEX(@w_ids, '", "', @i), '", "', -1);
                    set @v_name := SUBSTRING_INDEX(SUBSTRING_INDEX(@w_names, '", "', @i), '", "', -1);


                    #mysql 不能生命两个游标，采用查临时表的方式


                    #                         set @v_virtual_warehouse_id := '';
#                         set @v_virtual_warehouse_name := '';
                    #打开虚拟仓库的游标
#                         OPEN virtual_warehouse;
#                         FETCH virtual_warehouse INTO v_virtual_warehouse_id,v_virtual_warehouse_name;
#                         SET @j = 1;
#                         WHILE flag_a !=1
#                             DO
# #                                 如果当前的上传配置的虚拟仓ID和名称  不等于  虚拟仓库的ID和名称，就是有问题的，先记录下来，后面在看要不要些更新
#                                 if v_virtual_warehouse_id = @v_id and v_virtual_warehouse_name != @v_name then
# #                                                                     set abnormal := concat(abnormal,
# #                                                        concat(strategy_name, ':', v_store_name, ':',
# #                                                               v_virtual_warehouse_id, ':', @v_name,
# #                                                               ':', v_virtual_warehouse_name, ';'));
# #                                     select concat(strategy_name, ':', v_store_name, ':',
# #                                                   v_virtual_warehouse_id, ':', @v_name,
# #                                                   ':', v_virtual_warehouse_name, ';');
#                                 end if;
#
#                                 SET @j = @j + 1;
#                                 SET flag_a = flag_a + 1;
#                                 FETCH virtual_warehouse INTO v_virtual_warehouse_id,v_virtual_warehouse_name;
#
#                             end while;
#
#                     #关闭游标
#                         close virtual_warehouse;

                    set @v_virtual_warehouse_name = (
                        select virtual_warehouse_name
                        from oms_admin.oms_virtual_warehouse_tem
                        where virtual_warehouse_id = @v_id);

#                     select concat(@virtual_warehouse_name,@v_id,@v_name);

                    if
                        @v_virtual_warehouse_name != @v_name then
                        ##名称重复
                        set abnormal := concat(abnormal,
                                               concat(strategy_name, ':', v_store_name, ':',
                                                      @v_id, ':', @v_name,
                                                      ':', @v_virtual_warehouse_name, ';'));

#                         select strategy_name, v_store_name, @v_id, @v_name, @v_virtual_warehouse_name;
                    end if;

                    SET @i = @i + 1;
                end while;

# select strategy_name;
            FETCH strategy_id INTO strategy_name,v_store_name,s_id,s_name;
        end while;
    select abnormal;


    #关闭游标
    close strategy_id;
end;

