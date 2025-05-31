@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Clientes'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
@Metadata.allowExtensions: true
define view entity ZC_365_CLIENTES
  as select from ztb_365_clientes as Clientes
    inner join   ztb_365_cln_lib  as Clienteslibros on Clienteslibros.id_cliente = Clientes.id_cliente
{
  key Clienteslibros.id_libro as IdLibro,
  key Clientes.id_cliente     as IdCliente,
  key Clientes.tipo_acceso    as Acceso,
      Clientes.nombre         as Nombre,
      Clientes.apellidos      as Apellidos,
      Clientes.email          as Email,
      Clientes.url            as Imagen
}
